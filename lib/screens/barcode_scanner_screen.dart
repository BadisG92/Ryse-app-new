import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
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
  final Function(nutrition_models.FoodItem)? onFoodScanned; // Callback pour ajouter au journal
  
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
  bool isScanning = false;
  bool hasResult = false;
  bool isLoadingProduct = false;
  bool isFlashOn = false;
  bool isCameraInitialized = false;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _quantityController = TextEditingController();

  // Mobile scanner pour scan automatique
  MobileScannerController? _mobileScannerController;
  
  // Camera fallback pour web si nécessaire
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final ImagePicker _imagePicker = ImagePicker();
  File? _capturedImage;

  OpenFoodFactsProduct? _scannedProduct;
  nutrition_models.FoodItem? _pendingDashboardFoodItem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quantityController.text = '100'; // Quantité par défaut
    
    // Utiliser mobile_scanner par défaut, camera seulement en fallback pour web si nécessaire
    _mobileScannerController = MobileScannerController();
    if (kIsWeb) {
      _initializeCamera(); // Fallback pour web si mobile_scanner ne fonctionne pas
    }
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _mobileScannerController?.dispose();
    _cameraController?.dispose();
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

  Future<void> _initializeCamera() async {
    try {
      // Vérifier les permissions
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted) {
        setState(() {
          errorMessage = 'Permission caméra requise pour scanner les codes-barres';
        });
        return;
      }

      // Obtenir les caméras disponibles
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          errorMessage = 'Aucune caméra disponible sur cet appareil';
        });
        return;
      }

      // Initialiser le contrôleur de caméra avec la caméra arrière
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      setState(() {
        isCameraInitialized = true;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur d\'initialisation de la caméra: $e';
        isCameraInitialized = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    try {
      await _cameraController?.dispose();
      
      final currentCamera = _cameraController?.description;
      final newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection != currentCamera?.lensDirection,
        orElse: () => _cameras!.first,
      );
      
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      print('Erreur changement de caméra: $e');
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
        // Vue caméra réelle avec mobile_scanner
        if (!isLoadingProduct && !kIsWeb)
          MobileScanner(
            controller: _mobileScannerController!,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !isLoadingProduct) {
                final String code = barcodes.first.rawValue ?? '';
                if (code.isNotEmpty) {
                  _fetchProductData(code);
                }
              }
            },
          ),
          
        // Vue caméra fallback pour web
        if (!isLoadingProduct && kIsWeb)
          _buildCameraView(),
        
        // Vue caméra simulée pendant le chargement
        if (isLoadingProduct)
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
        ),
        
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
                
                // Ligne de scan animée
                if (!isLoadingProduct)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      top: _animation.value * 120,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF0B132B),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
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
        
        // Boutons d'action
        if (!isLoadingProduct)
        Positioned(
          bottom: 50,
          left: 24,
          right: 24,
            child: Column(
              children: [
                // Bouton scan automatique
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _restartScanning,
                    icon: const Icon(
                      LucideIcons.scan,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Scanner automatiquement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Bouton saisie manuelle
                SizedBox(
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
              ],
          ),
        ),
      ],
    );
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
          
          // Boutons d'action (seulement si pas d'erreur)
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
                  color: const Color(0xFFF1F5F9), // Fond gris de l'app
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                child: _scannedProduct!.imageUrl != null && _scannedProduct!.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _scannedProduct!.imageUrl!,
                          fit: BoxFit.contain, // Utilise contain au lieu de cover
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

  // Widget placeholder pour l'image du produit
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

  // Redémarrer le scan
  void _restartScanning() {
    // Relancer l'animation de scan
    if (!_animationController.isAnimating) {
      _animationController.repeat();
    }
  }

  // Contrôle du flash
  Future<void> _toggleFlash() async {
    try {
      setState(() {
        isFlashOn = !isFlashOn;
      });
      
      // Utiliser mobile_scanner pour le flash
      if (_mobileScannerController != null) {
        await _mobileScannerController!.toggleTorch();
      } else if (_cameraController != null) {
        // Fallback pour camera
        await _cameraController!.setFlashMode(
          isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      }
    } catch (e) {
      print('Erreur toggle flash: $e');
      // Revert state if error
      setState(() {
        isFlashOn = !isFlashOn;
      });
    }
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
              const Icon(
                LucideIcons.cameraOff,
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

  // Afficher la saisie manuelle du code-barres
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

  // Récupérer les données du produit depuis OpenFoodFacts
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

  void _handleAddToMeal() {
    if (_scannedProduct == null) return;
    
    print('DEBUG: _handleAddToMeal appelée, isFromDashboard: ${widget.isFromDashboard}');
    print('DEBUG: Barcode: ${_scannedProduct!.barcode}');

    if (widget.isFromDashboard) {
      // Mode dashboard - comportement existant
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
      // Mode journal - afficher le popup de choix de sauvegarde
      _showSaveChoiceDialog();
    }
  }

  void _handleDashboardFoodSelection(nutrition_models.FoodItem foodItem) {
    // Utiliser le callback si disponible (c'est le cas depuis le dashboard)
    if (widget.onFoodScanned != null) {
      Navigator.pop(context);
      widget.onFoodScanned!(foodItem);
    } else {
      // Fallback pour les anciens flux
      // Fermer d'abord l'écran du scanner
      Navigator.pop(context);
      
      // Attendre un délai pour que la fermeture soit complète puis utiliser le flux unifié
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          NutritionQuickActionsSection.showMealSelectionWithDetectedFood(context, foodItem);
        }
      });
    }
  }

  void _showSaveChoiceDialog() async {
    if (_scannedProduct == null) return;
    
    // Vérifier d'abord si l'aliment existe déjà
    final user = AuthService().currentUser;
    if (user != null && _scannedProduct!.barcode != null) {
      final existingFood = await DatabaseService.checkCustomFoodExistsByBarcode(
        user.id, 
        _scannedProduct!.barcode!
      );
      
      if (existingFood != null) {
        // L'aliment existe déjà, l'utiliser directement
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
                // Icône
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
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context); // Fermer le popup
                          _addScannedFoodDirectly(); // Ajouter sans sauvegarder
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
                          Navigator.pop(context); // Fermer popup
                          await _saveAndAddScannedFood(); // Sauvegarder puis ajouter
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
    // L'aliment existe déjà dans custom_foods, l'utiliser
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
    
    // Utiliser le callback si disponible
    if (widget.onFoodScanned != null) {
      Navigator.pop(context);
      widget.onFoodScanned!(foodItem);
    } else {
      _closeScreenWithSnackBar();
    }
  }

  Future<void> _addScannedFoodDirectly() async {
    // Ajouter l'aliment sans le sauvegarder dans custom_foods
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    final unit = _scannedProduct!.unit;
    
    // Utiliser le meilleur nom disponible
    String productName = _scannedProduct!.productName ?? 
                        _scannedProduct!.brands ?? 
                        'Produit scanné ${_scannedProduct!.barcode ?? ''}';
    
    final foodItem = nutrition_models.FoodItem(
      // Pas d'ID car pas sauvegardé dans custom_foods
      name: productName,
      calories: _getCalculatedCalories().round(),
      proteins: _getCalculatedProtein(),
      carbs: _getCalculatedCarbs(),
      fats: _getCalculatedFat(),
      portion: '${quantity.round()} $unit',
      isCustom: false, // Pas un aliment custom puisque pas sauvegardé
      isScanned: true, // Mais toujours scanné pour l'icône
    );
    
    // Utiliser le callback si disponible
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
      // Vérifier que l'utilisateur est connecté
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

      // DEBUG: Afficher les données du produit
      print('DEBUG - Données du produit avant sauvegarde:');
      print('- productName: ${_scannedProduct!.productName}');
      print('- barcode: ${_scannedProduct!.barcode}');
      print('- brands: ${_scannedProduct!.brands}');
      print('- quantity: ${_scannedProduct!.quantity}');
      
      // Utiliser le meilleur nom disponible
      String productName = _scannedProduct!.productName ?? 
                          _scannedProduct!.brands ?? 
                          'Produit scanné ${_scannedProduct!.barcode ?? ''}';
      
      print('- Nom final choisi: $productName');

      // Calculer les macros pour 100g/ml (base de référence)
      final currentQuantity = double.tryParse(_quantityController.text) ?? 100.0;
      final originalCalories = _scannedProduct!.nutriments?.energyKcal100g ?? 0.0;
      final originalProteins = _scannedProduct!.nutriments?.proteins100g ?? 0.0;
      final originalCarbs = _scannedProduct!.nutriments?.carbohydrates100g ?? 0.0;
      final originalFats = _scannedProduct!.nutriments?.fat100g ?? 0.0;

      // Si l'unité est en grammes ou ml, on peut convertir à la base 100g/ml
      final isWeightBasedUnit = _scannedProduct!.unit == 'g' || _scannedProduct!.unit == 'ml';
      
      final finalCalories = isWeightBasedUnit ? originalCalories.round() : _getCalculatedCalories().round();
      final finalProteins = isWeightBasedUnit ? originalProteins : _getCalculatedProtein();
      final finalCarbs = isWeightBasedUnit ? originalCarbs : _getCalculatedCarbs();
      final finalFats = isWeightBasedUnit ? originalFats : _getCalculatedFat();
      final finalQuantity = isWeightBasedUnit ? 100.0 : currentQuantity;
      final finalUnit = _scannedProduct!.unit;

      final customFood = {
        'user_id': user.id,
        'name': productName, // Utiliser le nom amélioré
        'calories': finalCalories,
        'proteins': finalProteins,
        'carbs': finalCarbs,
        'fats': finalFats,
        'reference_quantity': finalQuantity,
        'reference_unit_fr': finalUnit,
        'reference_unit_en': finalUnit,
        'origin': 'barcode', // Marquer comme provenant d'un scan
        'barcode': _scannedProduct!.barcode, // Sauvegarder le code-barres
      };

      print('DEBUG - Données à sauvegarder: $customFood');

      // Sauvegarder dans Supabase et récupérer l'ID
      final response = await SupabaseConfig.client
          .from('custom_foods')
          .insert(customFood)
          .select()
          .single();

      print('DEBUG - Réponse Supabase: $response');

      // Créer le FoodItem avec l'ID généré et les valeurs actuelles de la portion
      final userQuantity = double.tryParse(_quantityController.text) ?? 100.0;
      final userUnit = _scannedProduct!.unit;
      
      final foodItem = nutrition_models.FoodItem(
        id: response['id'].toString(),
        name: productName, // Utiliser le même nom amélioré
        calories: _getCalculatedCalories().round(),
        proteins: _getCalculatedProtein(),
        carbs: _getCalculatedCarbs(),
        fats: _getCalculatedFat(),
        portion: '${userQuantity.round()} $userUnit',
        isCustom: true,
        isScanned: true,
      );

      print('DEBUG - FoodItem créé: ${foodItem.name}');

      // Afficher confirmation de sauvegarde
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$productName ajouté à vos aliments personnalisés'),
            backgroundColor: const Color(0xFF0B132B),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Utiliser le callback si disponible
      if (widget.onFoodScanned != null) {
        Navigator.pop(context);
        widget.onFoodScanned!(foodItem);
      } else {
        _closeScreenWithSnackBar();
      }

    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
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
    // Obtenir le ScaffoldMessenger avant de fermer l'écran
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    Navigator.pop(context);
    
    // Utiliser le ScaffoldMessenger sauvegardé après fermeture
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
