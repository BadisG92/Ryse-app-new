import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../models/nutrition_models.dart' as nutrition_models;
import '../models/openfoodfacts_models.dart';
import '../services/openfoodfacts_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/barcode_detection_service.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import '../config/supabase_config.dart';
import '../config/google_vision_config.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool isFromDashboard;
  final Function(nutrition_models.FoodItem)? onFoodScanned; // Callback pour ajouter au journal
  final String? mealName;
  final String? mealId;

  const BarcodeScannerScreen({
    super.key,
    this.isFromDashboard = false,
    this.onFoodScanned,
    this.mealName,
    this.mealId,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with TickerProviderStateMixin {
  bool isScanning = false;
  bool hasResult = false;
  bool isLoadingProduct = false;
  bool isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _quantityController = TextEditingController();

  // Controllers pour les valeurs nutritionnelles éditables (par 100g)
  final TextEditingController _caloriesPer100gController = TextEditingController();
  final TextEditingController _proteinsPer100gController = TextEditingController();
  final TextEditingController _carbsPer100gController = TextEditingController();
  final TextEditingController _fatsPer100gController = TextEditingController();
  bool _isEditingNutritionalValues = false;

  CameraController? _cameraController;
  bool isCameraInitialized = false;

  // Tap-to-focus
  Offset? _focusPoint;
  bool _showFocusIndicator = false;

  OpenFoodFactsProduct? _scannedProduct;
  String? _errorMessage;
  nutrition_models.FoodItem? _pendingDashboardFoodItem;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '100'; // Quantité par défaut
    _initializeCamera();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    _animationController.repeat();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          isCameraInitialized = false;
        });
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFocusMode(FocusMode.auto);

      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation caméra: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
    _caloriesPer100gController.dispose();
    _proteinsPer100gController.dispose();
    _carbsPer100gController.dispose();
    _fatsPer100gController.dispose();
    _cameraController?.dispose();
    super.dispose();
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
        // Vue caméra avec tap-to-focus
        if (isCameraInitialized && _cameraController != null && !isLoadingProduct)
          GestureDetector(
            onTapDown: (details) async {
              if (isProcessing) return;

              final RenderBox box = context.findRenderObject() as RenderBox;
              final Offset localPosition = box.globalToLocal(details.globalPosition);
              final double x = localPosition.dx / box.size.width;
              final double y = localPosition.dy / box.size.height;

              try {
                await _cameraController!.setFocusPoint(Offset(x, y));
                await _cameraController!.setExposurePoint(Offset(x, y));

                setState(() {
                  _focusPoint = details.globalPosition;
                  _showFocusIndicator = true;
                });

                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _showFocusIndicator = false;
                    });
                  }
                });
              } catch (e) {
                debugPrint('❌ Erreur focus: $e');
              }
            },
            child: SizedBox.expand(
              child: CameraPreview(_cameraController!),
            ),
          ),

        // Vue caméra simulée pendant le chargement ou si pas initialisée
        if (!isCameraInitialized || isLoadingProduct)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
          ),

        // Indicateur de focus (tap-to-focus)
        if (_showFocusIndicator && _focusPoint != null)
          Positioned(
            left: _focusPoint!.dx - 40,
            top: _focusPoint!.dy - 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellow, width: 2),
                shape: BoxShape.circle,
              ),
            ),
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
              // Bouton saisie manuelle dans le header
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
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    isLoadingProduct
                        ? 'fetching_product'.tr(locService.currentLanguageCode)
                        : 'scanning_barcode'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    isLoadingProduct
                        ? 'searching_database'.tr(locService.currentLanguageCode)
                        : 'place_barcode_in_zone'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                // Bouton tap-to-scan
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : _scanBarcodeWithCamera,
                    icon: isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        isProcessing
                            ? 'analyzing'.tr(locService.currentLanguageCode)
                            : 'scan_barcode_button'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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
            label: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'enter_code_manually'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
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
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      _errorMessage != null
                          ? 'error'.tr(locService.currentLanguageCode)
                          : 'product_found'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _errorMessage != null ? _buildErrorContent() : _buildProductContent(),
          ),
          
          // Boutons d'action (seulement si pas d'erreur)
          if (_errorMessage == null && _scannedProduct != null)
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
            _errorMessage!,
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
                  _errorMessage = null;
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

                      const SizedBox(height: 16),

                      // Avertissement sur les données OpenFoodFacts
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFE69C)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 20,
                              color: Color(0xFF856404),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Les données proviennent d\'OpenFoodFacts et peuvent être inexactes. Vérifiez avec l\'emballage et modifiez si nécessaire.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF856404),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header avec bouton modifier
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pour la quantité indiquée',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setModalState(() {
                                      _isEditingNutritionalValues = !_isEditingNutritionalValues;
                                    });
                                  },
                                  icon: Icon(
                                    _isEditingNutritionalValues ? Icons.check : Icons.edit_outlined,
                                    size: 16,
                                  ),
                                  label: Consumer<LocalizationService>(
                                    builder: (context, locService, _) => Text(
                                      _isEditingNutritionalValues
                                          ? 'validate'.tr(locService.currentLanguageCode)
                                          : 'edit_values_per_100g'.tr(locService.currentLanguageCode),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Calories
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
                                if (_isEditingNutritionalValues)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: TextField(
                                          controller: _caloriesPer100gController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('kcal/100g', style: TextStyle(fontSize: 12)),
                                    ],
                                  )
                                else
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
                                const Text('Protéines', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                                if (_isEditingNutritionalValues)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: TextField(
                                          controller: _proteinsPer100gController,
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('g/100g', style: TextStyle(fontSize: 12)),
                                    ],
                                  )
                                else
                                  Text(
                                    '${_getCalculatedProtein().toStringAsFixed(1)} g',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Glucides
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Glucides', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                                if (_isEditingNutritionalValues)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: TextField(
                                          controller: _carbsPer100gController,
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('g/100g', style: TextStyle(fontSize: 12)),
                                    ],
                                  )
                                else
                                  Text(
                                    '${_getCalculatedCarbs().toStringAsFixed(1)} g',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Lipides
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Lipides', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                                if (_isEditingNutritionalValues)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: TextField(
                                          controller: _fatsPer100gController,
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('g/100g', style: TextStyle(fontSize: 12)),
                                    ],
                                  )
                                else
                                  Text(
                                    '${_getCalculatedFat().toStringAsFixed(1)} g',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
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
              onPressed: _errorMessage == null ? _handleAddToMeal : null,
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
                  _errorMessage = null;
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
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    final caloriesPer100g = double.tryParse(_caloriesPer100gController.text) ?? 0.0;
    return (caloriesPer100g * quantity / 100);
  }

  double _getCalculatedProtein() {
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    final proteinsPer100g = double.tryParse(_proteinsPer100gController.text) ?? 0.0;
    return (proteinsPer100g * quantity / 100);
  }

  double _getCalculatedCarbs() {
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    final carbsPer100g = double.tryParse(_carbsPer100gController.text) ?? 0.0;
    return (carbsPer100g * quantity / 100);
  }

  double _getCalculatedFat() {
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    final fatsPer100g = double.tryParse(_fatsPer100gController.text) ?? 0.0;
    return (fatsPer100g * quantity / 100);
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
  /// Scanner le code-barres avec Google Vision API (tap-to-scan)
  Future<void> _scanBarcodeWithCamera() async {
    if (isProcessing || !isCameraInitialized) return;

    setState(() {
      isProcessing = true;
      isLoadingProduct = true;
    });

    try {
      // Capturer une image haute résolution
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      debugPrint('📸 Image capturée, détection en cours...');

      // Détecter le code-barres avec Vision API + checksum validation
      final barcode = await BarcodeDetectionService.detectBarcode(imageBytes);

      if (!mounted) return;

      if (barcode != null) {
        debugPrint('✅ Code-barres détecté: $barcode');
        // Récupérer les données du produit
        await _fetchProductData(barcode);
      } else {
        debugPrint('⚠️ Aucun code-barres détecté');
        setState(() {
          isProcessing = false;
          isLoadingProduct = false;
        });
        // Afficher un message d'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun code-barres détecté. Touchez l\'écran pour faire la mise au point et réessayez.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur scan: $e');
      if (mounted) {
        setState(() {
          isProcessing = false;
          isLoadingProduct = false;
        });
      }
    }
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

          // Initialiser les valeurs nutritionnelles par 100g
          _caloriesPer100gController.text = (product.nutriments?.caloriesPer100g ?? 0).round().toString();
          _proteinsPer100gController.text = (product.nutriments?.proteinsPer100g ?? 0).toStringAsFixed(1);
          _carbsPer100gController.text = (product.nutriments?.carbohydratesPer100g ?? 0).toStringAsFixed(1);
          _fatsPer100gController.text = (product.nutriments?.fatPer100g ?? 0).toStringAsFixed(1);
          _isEditingNutritionalValues = false;

          isLoadingProduct = false;
      hasResult = true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = OpenFoodFactsService.getErrorMessage(product);
          isLoadingProduct = false;
          hasResult = true;
          _scannedProduct = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la récupération du produit';
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
      // Créer un FoodItem basé sur les données scannées
      final quantity = double.tryParse(_quantityController.text) ?? 100.0;
      final unit = _scannedProduct!.unit;
      final foodItem = nutrition_models.FoodItem(
        name: _scannedProduct!.productName ?? 'Produit scanné', // Juste le nom, sans les calories
        calories: _getCalculatedCalories().round(),
        proteins: _getCalculatedProtein(),
        carbs: _getCalculatedCarbs(),
        fats: _getCalculatedFat(),
        portion: '${quantity.round()} $unit',
        isScanned: true, // Marquer comme "scanné" pour utiliser l'icône de code-barres
      );
      
      // Afficher le popup AVANT de déclencher la sélection
      if (_scannedProduct!.barcode != null && _scannedProduct!.barcode!.isNotEmpty) {
        print('DEBUG: Dashboard - Affichage du popup');
        _pendingDashboardFoodItem = foodItem; // Stocker pour après le popup
        _showSaveToCustomFoodsDialog();
      } else {
        // Pas de code-barres, comportement normal
        print('DEBUG: Dashboard - Pas de code-barres, sélection directe');
      _handleDashboardFoodSelection(foodItem);
      }
    } else {
      // Comportement pour le journal - Afficher le popup d'abord
      if (_scannedProduct!.barcode != null && _scannedProduct!.barcode!.isNotEmpty) {
        print('DEBUG: Mode Journal - Affichage immédiat du popup');
        _showSaveToCustomFoodsDialog();
        // La fermeture de l'écran sera gérée dans le popup lui-même
      } else {
        // Pas de code-barres, comportement normal
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Produit ajouté au repas'),
            backgroundColor: const Color(0xFF0B132B),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
            ),
          ),
        );
      }
    }
  }

  void _closeScreenWithSnackBar() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Produit ajouté au repas'),
        backgroundColor: const Color(0xFF0B132B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          top: 50,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  void _handleJournalFoodAddition() {
    if (_scannedProduct == null) return;
    
    // Créer le FoodItem avec les données scannées
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    final unit = _scannedProduct!.unit;
    final foodItem = nutrition_models.FoodItem(
      name: _scannedProduct!.productName ?? 'Produit scanné', // Juste le nom, sans les calories
      calories: _getCalculatedCalories().round(),
      proteins: _getCalculatedProtein(),
      carbs: _getCalculatedCarbs(),
      fats: _getCalculatedFat(),
      portion: '${quantity.round()} $unit',
      isScanned: true, // Marquer comme "scanné" pour utiliser l'icône de code-barres
    );
    
    // Utiliser le callback si disponible, sinon fermer avec message
    if (widget.onFoodScanned != null) {
      Navigator.pop(context); // Fermer l'écran scanner
      widget.onFoodScanned!(foodItem); // Appeler le callback
    } else {
      _closeScreenWithSnackBar(); // Fallback : ancien comportement
    }
  }

  void _showSaveToCustomFoodsDialog() async {
    if (_scannedProduct == null) return;
    
    print('DEBUG: _showSaveToCustomFoodsDialog appelée');

    // Vérifier d'abord si l'aliment existe déjà
    final user = AuthService().currentUser;
    if (user != null && _scannedProduct!.barcode != null) {
      final existingFood = await DatabaseService.checkCustomFoodExistsByBarcode(
        user.id, 
        _scannedProduct!.barcode!
      );
      
      if (existingFood != null) {
        // L'aliment existe déjà, ne pas afficher le popup de sauvegarde
        // mais continuer avec l'ajout au repas
        if (mounted) {
          // Afficher message d'information (optionnel)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_scannedProduct!.productName ?? 'Ce produit'} est déjà dans vos aliments personnalisés'),
              backgroundColor: const Color(0xFF059669),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(
                top: 50,
                left: 20,
                right: 20,
              ),
            ),
          );
          
          // Continuer avec l'ajout au repas sans popup de sauvegarde
          if (widget.isFromDashboard && _pendingDashboardFoodItem != null) {
            _handleDashboardFoodSelection(_pendingDashboardFoodItem!);
          } else {
            // Mode journal : créer le FoodItem et utiliser le callback
            _handleJournalFoodAddition();
          }
        }
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
                  'Souhaitez-vous ajouter "${_scannedProduct!.productName ?? 'ce produit'}" à vos aliments personnalisés ?',
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
                          if (widget.isFromDashboard && _pendingDashboardFoodItem != null) {
                            _handleDashboardFoodSelection(_pendingDashboardFoodItem!);
                          } else {
                            _handleJournalFoodAddition(); // Mode journal
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Non',
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
                          await _saveToCustomFoods();
                          if (widget.isFromDashboard && _pendingDashboardFoodItem != null) {
                            _handleDashboardFoodSelection(_pendingDashboardFoodItem!);
                          } else {
                            _handleJournalFoodAddition(); // Mode journal
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Oui',
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

  Future<void> _saveToCustomFoods() async {
    if (_scannedProduct == null) return;

    try {
      // Vérifier que l'utilisateur est connecté
      final user = AuthService().currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vous devez être connecté pour sauvegarder un aliment'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(
                top: 50,
                left: 20,
                right: 20,
              ),
            ),
          );
        }
        return;
      }

      // Calculer les macros pour 100g/ml (base de référence)
      final currentQuantity = double.tryParse(_quantityController.text) ?? 100.0;
      final originalCalories = _scannedProduct!.nutriments?.energyKcal100g ?? 0.0;
      final originalProteins = _scannedProduct!.nutriments?.proteins100g ?? 0.0;
      final originalCarbs = _scannedProduct!.nutriments?.carbohydrates100g ?? 0.0;
      final originalFats = _scannedProduct!.nutriments?.fat100g ?? 0.0;

      // Si l'unité est en grammes ou ml, on peut convertir à la base 100g/ml
      // Sinon, on garde les valeurs actuelles
      final isWeightBasedUnit = _scannedProduct!.unit == 'g' || _scannedProduct!.unit == 'ml';
      
      final finalCalories = isWeightBasedUnit ? originalCalories.round() : _getCalculatedCalories().round();
      final finalProteins = isWeightBasedUnit ? originalProteins : _getCalculatedProtein();
      final finalCarbs = isWeightBasedUnit ? originalCarbs : _getCalculatedCarbs();
      final finalFats = isWeightBasedUnit ? originalFats : _getCalculatedFat();
      final finalQuantity = isWeightBasedUnit ? 100.0 : currentQuantity;
      final finalUnit = _scannedProduct!.unit;

      final customFood = {
        'user_id': user.id,
        'name': _scannedProduct!.productName ?? 'Produit scanné',
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

      // Sauvegarder dans Supabase
      final response = await SupabaseConfig.client
          .from('custom_foods')
          .insert(customFood)
          .select()
          .single();

      // Afficher une confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_scannedProduct!.productName ?? 'Produit'} ajouté à vos aliments personnalisés'),
            backgroundColor: const Color(0xFF0B132B),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
            ),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Naviguer vers la liste des aliments personnalisés
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e'); // Pour le debug
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
            ),
          ),
        );
      }
    }
  }

  void _handleDashboardFoodSelection(nutrition_models.FoodItem foodItem) {
    // Simuler des repas existants
    final existingMeals = <nutrition_models.Meal>[
      nutrition_models.Meal(
        name: 'Petit-déjeuner',
        time: '08:30',
        items: [
          nutrition_models.FoodItem(
            name: 'Café',
            calories: 5,
            portion: '1 tasse',
          ),
        ],
      ),
      nutrition_models.Meal(
        name: 'Déjeuner',
        time: '12:45',
        items: [
          nutrition_models.FoodItem(
            name: 'Salade',
            calories: 150,
            portion: '200g',
          ),
        ],
      ),
    ];

    // Sauvegarder le contexte avant de fermer l'écran
    final currentContext = context;
    
    // Fermer l'écran du scanner
    Navigator.pop(context);
    
    // Attendre un délai pour permettre au popup de se fermer s'il était ouvert
    Future.delayed(const Duration(milliseconds: 100), () {
      if (currentContext.mounted) {
    MealSelectionBottomSheet.show(
          currentContext,
      foodName: foodItem.name,
      existingMeals: existingMeals,
      onExistingMealSelected: (meal) {
        // TODO: Ajouter l'aliment au repas sélectionné
            // Ajouter l'aliment au repas sélectionné
      },
      onCreateNewMeal: () {
            // Utiliser le contexte sauvegardé
        NewMealTypeBottomSheet.show(
              currentContext,
          onMealTypeSelected: (mealType, time) {
            // TODO: Créer un nouveau repas avec l'aliment
                // Créer un nouveau repas avec l'aliment
          },
        );
      },
    );
      }
    });
  }
} 
