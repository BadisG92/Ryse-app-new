import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

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
import '../services/analytics_service.dart';
import '../services/celebration_service.dart';
import '../services/food_entries_service.dart';
// import '../services/barcode_detection_service.dart'; // ANCIEN - Remplacé par unified_barcode_service
import '../services/unified_barcode_service.dart'; // NOUVEAU - Switch ML Kit / Vision API
import '../services/subscription_service.dart';
import '../services/paywall_service.dart';
import '../services/feature_trial_service.dart';
import '../services/translations.dart';
import '../design/design.dart';
import '../components/ui/numeric_text_field.dart';
import '../services/barcode_stream_service.dart';
import '../services/localization_service.dart';
import '../config/supabase_config.dart';

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

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool isScanning = false;
  bool hasResult = false;
  bool isLoadingProduct = false;
  bool isProcessing = false;
  final TextEditingController _quantityController = TextEditingController();

  // Controllers pour les valeurs nutritionnelles éditables (par 100g)
  final TextEditingController _caloriesPer100gController = TextEditingController();
  final TextEditingController _proteinsPer100gController = TextEditingController();
  final TextEditingController _carbsPer100gController = TextEditingController();
  final TextEditingController _fatsPer100gController = TextEditingController();
  bool _isEditingNutritionalValues = false;

  CameraController? _cameraController;
  bool isCameraInitialized = false;

  /// La lecture en continu. Null tant que la caméra n'est pas prête, et
  /// abandonnée si l'appareil ne sait pas nous donner ses images.
  BarcodeStreamService? _live;

  /// Vrai tant que le flux lit : le déclencheur reste caché.
  bool _liveOn = false;

  /// Le code vient d'être reconnu : le cadre se referme avant que l'écran
  /// change, pour qu'on voie ce qui s'est passé.
  bool _caught = false;

  OpenFoodFactsProduct? _scannedProduct;
  String? _errorMessage;
  nutrition_models.FoodItem? _pendingDashboardFoodItem;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '100'; // Quantité par défaut

    // Vérifier accès Premium après que le widget soit monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPremiumAccess();
    });
  }

  /// Vérifier si l'utilisateur a accès au scanner barcode (Premium uniquement ou Trial)
  Future<void> _checkPremiumAccess() async {
    // Utiliser canUseFeature pour gérer le trial
    // markAsUsed: false car on marque seulement après succès
    final canAccess = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.barcodeScanner,
      markAsUsed: false,
    );

    if (!canAccess) {
      // L'utilisateur n'a pas accès (ni Premium, ni trial, et a refusé le paywall)
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    // Si accès autorisé, initialiser la caméra
    _initializeCamera();
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

      // La lecture en continu veut des images modestes : en haute résolution
      // chaque trame coûte plus à convertir qu'à lire.
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );

      await _cameraController?.initialize();
      await _cameraController?.setFocusMode(FocusMode.auto);

      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
        _startLiveScan();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur initialisation caméra: $e');
    }
  }

  /// Lire les images au vol. Sur un appareil qui ne sait pas les fournir dans
  /// un format que ML Kit accepte, on retombe simplement sur le déclencheur :
  /// l'utilisateur ne perd rien, il appuie comme avant.
  Future<void> _startLiveScan() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final live = BarcodeStreamService(controller);
    _live = live;
    setState(() => _liveOn = true);
    await live.start(
      onCode: (code) async {
        if (!mounted || hasResult || isLoadingProduct) return;
        RyzeFeedback.success();
        setState(() {
          _caught = true;
          _liveOn = false;
          isProcessing = true;
          isLoadingProduct = true;
        });
        AnalyticsService.logFoodScanBarcode(
          mealType: widget.mealName ?? 'unknown',
          success: true,
          source: 'live',
        );
        // laisser le cadre se refermer avant de changer d'écran
        await Future.delayed(const Duration(milliseconds: 220));
        if (mounted) await _fetchProductData(code);
      },
      onUnavailable: () {
        if (mounted) setState(() => _liveOn = false);
      },
    );
  }

  @override
  void dispose() {
    _live?.stop();
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
    if (hasResult) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: _buildResultScreen()),
      );
    }
    return _buildScannerScreen();
  }

  Widget _buildScannerScreen() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return RyzeCameraShell(
      controller: _cameraController,
      ready: isCameraInitialized && _cameraController != null,
      title: 'scan_barcode'.tr(lang),
      hint: isLoadingProduct
          ? 'searching_database'.tr(lang)
          : (_liveOn ? 'barcode_point_at_code'.tr(lang) : 'place_barcode_in_zone'.tr(lang)),
      onClose: () => Navigator.pop(context),
      frame: BarcodeFrame(found: _caught),
      busy: isProcessing,
      // Quand le flux lit, il n'y a rien à appuyer : c'est tout l'intérêt.
      shutter: _liveOn ? null : (isProcessing ? () {} : _scanBarcodeWithCamera),
      leftIcon: LucideIcons.type,
      leftLabel: 'enter_barcode_manually'.tr(lang),
      leftAction: _showManualBarcodeInput,
      overlay: isLoadingProduct
          ? Positioned.fill(
              child: ColoredBox(
                color: RyzeColors.ink.withValues(alpha: 0.45),
                child: const Center(child: CircularProgressIndicator(color: RyzeColors.surf, strokeWidth: 2)),
              ),
            )
          : null,
    );
  }


  Widget _buildResultScreen() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: RyzeColors.ink.withValues(alpha: 0.92)),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(2.1), context.vw(4.1), context.vw(2.1)),
                child: Row(
                  children: [
                    Pressable(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: context.vw(10.8),
                        height: context.vw(10.8),
                        decoration: BoxDecoration(
                          color: RyzeColors.surf.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.x, size: context.vw(4.6), color: RyzeColors.surf),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _errorMessage != null ? 'error'.tr(lang) : 'product_found'.tr(lang),
                        textAlign: TextAlign.center,
                        style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
                      ),
                    ),
                    SizedBox(width: context.vw(10.8)),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: RyzeColors.paper,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(RyzeRadius.lg)),
                  ),
                  child: _errorMessage != null ? _buildErrorContent() : _buildProductContent(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Le code n'a rien donné. Deux suites possibles, et aucune n'est un
  /// cul-de-sac : recommencer, ou saisir le code à la main.
  Widget _buildErrorContent() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.vw(8), vertical: context.vw(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.packageX, size: context.vw(12.3), color: RyzeColors.mute2),
          SizedBox(height: context.vw(4.1)),
          Text(
            _errorMessage ?? 'error'.tr(lang),
            textAlign: TextAlign.center,
            style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.mute),
          ),
          SizedBox(height: context.vw(6.2)),
          Pressable(
            onTap: _rescan,
            child: Container(
              height: context.vw(13.3),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: RyzeColors.ink,
                borderRadius: BorderRadius.circular(RyzeRadius.sm),
                boxShadow: RyzeShadow.soft,
              ),
              child: Text('scan_another'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
            ),
          ),
          SizedBox(height: context.vw(3.1)),
          Pressable(
            onTap: () {
              _rescan();
              _showManualBarcodeInput();
            },
            child: Container(
              height: context.vw(13.3),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: RyzeColors.surf,
                borderRadius: BorderRadius.circular(RyzeRadius.sm),
                border: Border.all(color: RyzeColors.line),
              ),
              child: Text('enter_barcode_manually'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  /// Retourner au viseur, et relancer la lecture en continu.
  void _rescan() {
    setState(() {
      hasResult = false;
      _errorMessage = null;
      _scannedProduct = null;
      _caught = false;
      isProcessing = false;
      isLoadingProduct = false;
    });
    _startLiveScan();
  }

  /// Le produit : ce que c'est, combien on en prend, ce que ça vaut.
  ///
  /// La quantité mène, comme partout ailleurs depuis la refonte. Les valeurs
  /// par 100 g restent corrigeables, mais derrière un bouton plutôt qu'étalées
  /// en quatre champs qu'on ne touchera jamais.
  Widget _buildProductContent() {
    final lang = LocalizationService.instance.currentLanguageCode;
    final unit = (_scannedProduct?.unit ?? 'g').toLowerCase() == 'ml' ? 'ml' : 'g';
    final gutter = context.vw(5.1);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, context.vw(4.6), gutter, context.vw(4.1)),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(RyzeRadius.sm),
                    child: SizedBox(
                      width: context.vw(18.5),
                      height: context.vw(18.5),
                      child: (_scannedProduct?.imageUrl?.isNotEmpty ?? false)
                          ? Image.network(
                              _scannedProduct!.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                    ),
                  ),
                  SizedBox(width: context.vw(3.6)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scannedProduct?.productName ?? 'no_additional_info'.tr(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: RyzeText.body(context, 4.6, weight: FontWeight.w600),
                        ),
                        SizedBox(height: context.vw(1)),
                        Text(
                          _buildProductSubtitle(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.vw(5.6)),

              // La quantité, en grand, avec les portions courantes.
              _BarcodeQuantity(
                controller: _quantityController,
                unit: unit,
                lang: lang,
                onChanged: () => setState(() {}),
              ),
              SizedBox(height: context.vw(5.1)),

              Container(
                padding: EdgeInsets.all(context.vw(4.1)),
                decoration: BoxDecoration(
                  color: RyzeColors.surf,
                  borderRadius: BorderRadius.circular(RyzeRadius.md),
                  border: Border.all(color: RyzeColors.line),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('calories'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                        ),
                        RollingNumber(
                          '${_getCalculatedCalories().round()}',
                          style: RyzeText.display(context, 6.9, weight: FontWeight.w600),
                        ),
                        SizedBox(width: context.vw(1.5)),
                        Padding(
                          padding: EdgeInsets.only(top: context.vw(1.5)),
                          child: Text('kcal', style: RyzeText.body(context, 3.3, color: RyzeColors.mute)),
                        ),
                        SizedBox(width: context.vw(2.6)),
                        Pressable(
                          onTap: () {
                            RyzeFeedback.tap();
                            setState(() => _isEditingNutritionalValues = !_isEditingNutritionalValues);
                          },
                          child: Container(
                            width: context.vw(8.7),
                            height: context.vw(8.7),
                            decoration: BoxDecoration(
                              color: _isEditingNutritionalValues ? RyzeColors.ink : RyzeColors.paper,
                              shape: BoxShape.circle,
                              border: Border.all(color: _isEditingNutritionalValues ? RyzeColors.ink : RyzeColors.line),
                            ),
                            child: Icon(
                              _isEditingNutritionalValues ? LucideIcons.check : LucideIcons.pencil,
                              size: context.vw(4.1),
                              color: _isEditingNutritionalValues ? RyzeColors.surf : RyzeColors.mute,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.vw(3.6)),
                    const Divider(height: 1, color: RyzeColors.line),
                    SizedBox(height: context.vw(3.1)),
                    if (_isEditingNutritionalValues)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.vw(2.6)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'macros_per'.tr(lang).replaceAll('{q}', '100 $unit'),
                            style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                          ),
                        ),
                      ),
                    _BarcodeMacro(
                      label: 'calories'.tr(lang),
                      controller: _caloriesPer100gController,
                      editing: _isEditingNutritionalValues,
                      value: _getCalculatedCalories(),
                      suffix: 'kcal',
                      onChanged: () => setState(() {}),
                      hidden: !_isEditingNutritionalValues,
                    ),
                    _BarcodeMacro(
                      label: 'proteins'.tr(lang),
                      controller: _proteinsPer100gController,
                      editing: _isEditingNutritionalValues,
                      value: _getCalculatedProtein(),
                      suffix: 'g',
                      onChanged: () => setState(() {}),
                    ),
                    SizedBox(height: context.vw(2.6)),
                    _BarcodeMacro(
                      label: 'carbs'.tr(lang),
                      controller: _carbsPer100gController,
                      editing: _isEditingNutritionalValues,
                      value: _getCalculatedCarbs(),
                      suffix: 'g',
                      onChanged: () => setState(() {}),
                    ),
                    SizedBox(height: context.vw(2.6)),
                    _BarcodeMacro(
                      label: 'fats'.tr(lang),
                      controller: _fatsPer100gController,
                      editing: _isEditingNutritionalValues,
                      value: _getCalculatedFat(),
                      suffix: 'g',
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.vw(3.1)),

              // D'où viennent ces chiffres. Une ligne discrète, pas un panneau
              // d'avertissement jaune : l'information est utile, pas alarmante.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: context.vw(3.6), color: RyzeColors.mute2),
                  SizedBox(width: context.vw(2.1)),
                  Expanded(
                    child: Text(
                      'openfoodfacts_disclaimer'.tr(lang),
                      style: RyzeText.body(context, 2.9, color: RyzeColors.mute2, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Container(
      padding: EdgeInsets.fromLTRB(context.vw(5.1), context.vw(3.1), context.vw(5.1), context.vw(4.6)),
      decoration: const BoxDecoration(
        color: RyzeColors.paper,
        border: Border(top: BorderSide(color: RyzeColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: _rescan,
              child: Container(
                height: context.vw(13.3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: RyzeColors.surf,
                  borderRadius: BorderRadius.circular(RyzeRadius.sm),
                  border: Border.all(color: RyzeColors.line),
                ),
                child: Text('scan_another'.tr(lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
              ),
            ),
          ),
          SizedBox(width: context.vw(3.1)),
          Expanded(
            flex: 2,
            child: Pressable(
              onTap: _errorMessage == null ? _handleAddToMeal : null,
              child: Container(
                height: context.vw(13.3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: RyzeColors.ink,
                  borderRadius: BorderRadius.circular(RyzeRadius.sm),
                  boxShadow: RyzeShadow.soft,
                ),
                child: Text('add_to_meal'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return ColoredBox(
      color: RyzeColors.paper2,
      child: Icon(LucideIcons.package, size: context.vw(7.7), color: RyzeColors.mute2),
    );
  }


  String _buildProductSubtitle() {
    final parts = <String>[];
    final lang = LocalizationService.instance.currentLanguageCode;

    if ((_scannedProduct?.brands?.isNotEmpty ?? false)) {
      String brandLabel;
      if (lang == 'fr') {
        brandLabel = 'Marque';
      } else if (lang == 'de') {
        brandLabel = 'Marke';
      } else {
        brandLabel = 'Brand';
      }
      parts.add('$brandLabel: ${_scannedProduct?.brands}');
    }

    if ((_scannedProduct?.quantity?.isNotEmpty ?? false)) {
      parts.add(_scannedProduct?.quantity ?? '');
    }

    return parts.isNotEmpty ? parts.join(' • ') : 'no_additional_info'.tr(lang);
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

  // Redémarrer le scan
  /// Scanner le code-barres (ML Kit ou Vision API selon config)
  Future<void> _scanBarcodeWithCamera() async {
    if (isProcessing || !isCameraInitialized || _cameraController == null) return;

    setState(() {
      isProcessing = true;
      isLoadingProduct = true;
    });

    try {
      // Capturer une image haute résolution
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;
      final image = await _cameraController!.takePicture();

      if (kDebugMode) debugPrint('📸 Image capturée, détection en cours...');

      // NOUVEAU: Détecter avec le service unifié (ML Kit ou Vision API)
      final barcode = await UnifiedBarcodeService.detectBarcode(image.path);

      if (!mounted) return;

      if (barcode != null) {
        if (kDebugMode) debugPrint('✅ Code-barres détecté: $barcode');

        // 📊 Analytics: Barcode scan success
        AnalyticsService.logFoodScanBarcode(
          mealType: widget.mealName ?? 'unknown',
          success: true,
          source: 'camera',
        );

        // Récupérer les données du produit
        await _fetchProductData(barcode);
      } else {
        if (kDebugMode) debugPrint('⚠️ Aucun code-barres détecté');

        // 📊 Analytics: Barcode scan failed
        AnalyticsService.logFoodScanBarcode(
          mealType: widget.mealName ?? 'unknown',
          success: false,
          source: 'camera',
        );

        setState(() {
          isProcessing = false;
          isLoadingProduct = false;
        });
        // Afficher un message d'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('no_barcode_detected'.tr(LocalizationService.instance.currentLanguageCode)),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur scan: $e');
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
    final locService = LocalizationService.instance;
    final lang = locService.currentLanguageCode;
    final isFr = lang == 'fr';
    final isDe = lang == 'de';

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
                  Text(
                    isFr ? 'Saisie manuelle' : isDe ? 'Manuelle Eingabe' : 'Manual entry',
                    style: const TextStyle(
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
                  Text(
                    isFr
                        ? 'Entrez le code-barres du produit que vous souhaitez ajouter :'
                        : isDe
                            ? 'Geben Sie den Barcode des Produkts ein:'
                            : 'Enter the barcode of the product you want to add:',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
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
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.scan,
                        color: Color(0xFF64748B),
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    isFr ? 'Annuler' : isDe ? 'Abbrechen' : 'Cancel',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: (barcodeController.text.isNotEmpty && !isLoading)
                      ? () async {
                          setState(() => isLoading = true);

                          // 📊 Analytics: Manual barcode entry
                          AnalyticsService.logFoodScanBarcode(
                            mealType: widget.mealName ?? 'unknown',
                            success: true,
                            source: 'manual',
                          );

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
                      : Text(
                          isFr ? 'Rechercher' : isDe ? 'Suchen' : 'Search',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
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
          // Utiliser toujours 100g/100ml par défaut (base de référence nutritionnelle)
          _quantityController.text = '100';

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

        // ✅ Marquer le trial comme utilisé UNIQUEMENT si le produit a été trouvé
        if (!SubscriptionService.instance.isPremium) {
          FeatureTrialService.instance.markFeatureAsUsed(
            FeatureTrialService.keyBarcode,
          );
          if (kDebugMode) debugPrint('✅ Barcode scanner trial marked as used after successful product fetch');
        }
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
        _errorMessage = 'error_fetching_product'.tr(LocalizationService.instance.currentLanguageCode);
        isLoadingProduct = false;
        hasResult = true;
        _scannedProduct = null;
      });
    }
  }

  void _handleAddToMeal() {
    if (_scannedProduct == null) return;
    
    if (kDebugMode) debugPrint('DEBUG: _handleAddToMeal appelée, isFromDashboard: ${widget.isFromDashboard}');
    if (kDebugMode) debugPrint('DEBUG: Barcode: ${_scannedProduct!.barcode}');

    if (widget.isFromDashboard) {
      // Créer un FoodItem basé sur les données scannées
      final quantity = double.tryParse(_quantityController.text) ?? 100.0;
      final unit = _scannedProduct?.unit ?? 'g';
      final foodItem = nutrition_models.FoodItem(
        name: _scannedProduct?.productName ?? 'Produit scanné', // Juste le nom, sans les calories
        calories: _getCalculatedCalories().round(),
        proteins: _getCalculatedProtein(),
        carbs: _getCalculatedCarbs(),
        fats: _getCalculatedFat(),
        portion: '${quantity.round()} $unit',
        isScanned: true, // Marquer comme "scanné" pour utiliser l'icône de code-barres
      );
      
      // Afficher le popup AVANT de déclencher la sélection
      if ((_scannedProduct?.barcode?.isNotEmpty ?? false)) {
        if (kDebugMode) debugPrint('DEBUG: Dashboard - Affichage du popup');
        _pendingDashboardFoodItem = foodItem; // Stocker pour après le popup
        _showSaveToCustomFoodsDialog();
      } else {
        // Pas de code-barres, comportement normal
        if (kDebugMode) debugPrint('DEBUG: Dashboard - Pas de code-barres, sélection directe');
      _handleDashboardFoodSelection(foodItem);
      }
    } else {
      // Comportement pour le journal - Afficher le popup d'abord
      if ((_scannedProduct?.barcode?.isNotEmpty ?? false)) {
        if (kDebugMode) debugPrint('DEBUG: Mode Journal - Affichage immédiat du popup');
        _showSaveToCustomFoodsDialog();
        // La fermeture de l'écran sera gérée dans le popup lui-même
      } else {
        // Pas de code-barres, comportement normal
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product_added_to_meal'.tr(LocalizationService.instance.currentLanguageCode)),
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
        content: Text('product_added_to_meal'.tr(LocalizationService.instance.currentLanguageCode)),
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
    final unit = _scannedProduct?.unit ?? 'g';
    final foodItem = nutrition_models.FoodItem(
      name: _scannedProduct?.productName ?? 'Produit scanné', // Juste le nom, sans les calories
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
    
    if (kDebugMode) debugPrint('DEBUG: _showSaveToCustomFoodsDialog appelée');

    // Vérifier d'abord si l'aliment existe déjà
    final user = AuthService().currentUser;
    if (user != null && (_scannedProduct?.barcode?.isNotEmpty ?? false)) {
      final existingFood = await DatabaseService.checkCustomFoodExistsByBarcode(
        user.id, 
        _scannedProduct!.barcode!
      );
      
      if (existingFood != null) {
        // L'aliment existe déjà, ne pas afficher le popup de sauvegarde
        // mais continuer avec l'ajout au repas
        if (mounted) {
          // Afficher message d'information (optionnel)
          final productName = _scannedProduct?.productName ?? 'this_product'.tr(LocalizationService.instance.currentLanguageCode);
          final message = 'product_already_in_custom_foods'.tr(LocalizationService.instance.currentLanguageCode)
              .replaceAll('{productName}', productName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
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

                Consumer<LocalizationService>(
                  builder: (context, locService, child) {
                    String title;
                    if (locService.currentLanguageCode == 'fr') {
                      title = 'Sauvegarder l\'aliment ?';
                    } else if (locService.currentLanguageCode == 'de') {
                      title = 'Lebensmittel speichern?';
                    } else {
                      title = 'Save food item?';
                    }
                    return Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                Consumer<LocalizationService>(
                  builder: (context, locService, child) {
                    final productName = _scannedProduct?.productName ?? 'this_product'.tr(locService.currentLanguageCode);
                    final message = 'add_to_custom_foods_question'.tr(locService.currentLanguageCode)
                        .replaceAll('{productName}', productName);
                    return Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
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
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, child) {
                            String label;
                            if (locService.currentLanguageCode == 'fr') {
                              label = 'Non';
                            } else if (locService.currentLanguageCode == 'de') {
                              label = 'Nein';
                            } else {
                              label = 'No';
                            }
                            return Text(
                              label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            );
                          },
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
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, child) {
                            String label;
                            if (locService.currentLanguageCode == 'fr') {
                              label = 'Oui';
                            } else if (locService.currentLanguageCode == 'de') {
                              label = 'Ja';
                            } else {
                              label = 'Yes';
                            }
                            return Text(
                              label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            );
                          },
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
              content: Text('must_be_logged_in'.tr(LocalizationService.instance.currentLanguageCode)),
              backgroundColor: const Color(0xFFEF4444),
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
      final originalCalories = _scannedProduct?.nutriments?.energyKcal100g ?? 0.0;
      final originalProteins = _scannedProduct?.nutriments?.proteins100g ?? 0.0;
      final originalCarbs = _scannedProduct?.nutriments?.carbohydrates100g ?? 0.0;
      final originalFats = _scannedProduct?.nutriments?.fat100g ?? 0.0;

      // Si l'unité est en grammes ou ml, on peut convertir à la base 100g/ml
      // Sinon, on garde les valeurs actuelles
      final isWeightBasedUnit = _scannedProduct?.unit == 'g' || _scannedProduct?.unit == 'ml';
      
      final finalCalories = isWeightBasedUnit ? originalCalories.round() : _getCalculatedCalories().round();
      final finalProteins = isWeightBasedUnit ? originalProteins : _getCalculatedProtein();
      final finalCarbs = isWeightBasedUnit ? originalCarbs : _getCalculatedCarbs();
      final finalFats = isWeightBasedUnit ? originalFats : _getCalculatedFat();
      final finalQuantity = isWeightBasedUnit ? 100.0 : currentQuantity;
      final finalUnit = _scannedProduct?.unit ?? 'g';

      final customFood = {
        'user_id': user.id,
        'name': _scannedProduct?.productName ?? 'scanned_product'.tr(LocalizationService.instance.currentLanguageCode),
        'calories': finalCalories,
        'proteins': finalProteins,
        'carbs': finalCarbs,
        'fats': finalFats,
        'reference_quantity': finalQuantity,
        'reference_unit_fr': finalUnit,
        'reference_unit_en': finalUnit,
        'origin': 'barcode', // Marquer comme provenant d'un scan
        'barcode': _scannedProduct?.barcode, // Sauvegarder le code-barres
      };

      // Sauvegarder dans Supabase
      final response = await SupabaseConfig.client
          .from('custom_foods')
          .insert(customFood)
          .select()
          .single();

      // Afficher une confirmation
      if (mounted) {
        final lang = LocalizationService.instance.currentLanguageCode;
        final productName = _scannedProduct?.productName ?? 'meal_dish'.tr(lang);
        final message = 'product_added_to_custom_foods'.tr(lang)
            .replaceAll('{productName}', productName);

        String viewLabel;
        if (lang == 'fr') {
          viewLabel = 'Voir';
        } else if (lang == 'de') {
          viewLabel = 'Ansehen';
        } else {
          viewLabel = 'View';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF0B132B),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
            ),
            action: SnackBarAction(
              label: viewLabel,
              textColor: Colors.white,
              onPressed: () {
                // TODO: Naviguer vers la liste des aliments personnalisés
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de la sauvegarde: $e'); // Pour le debug
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_save_failed'.tr(LocalizationService.instance.currentLanguageCode)),
            backgroundColor: const Color(0xFFEF4444),
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

  Future<void> _handleDashboardFoodSelection(nutrition_models.FoodItem foodItem) async {
    // Utiliser le callback si disponible (flux normal depuis les actions rapides)
    if (widget.onFoodScanned != null) {
      Navigator.pop(context);
      widget.onFoodScanned!(foodItem);
      return;
    }

    // Fallback : charger les vrais repas depuis la base de données
    final user = AuthService().currentUser;
    if (user == null) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('must_be_logged_in'.tr(LocalizationService.instance.currentLanguageCode)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    // Récupérer les vrais repas du jour
    List<nutrition_models.Meal> existingMeals = [];
    try {
      final meals = await FoodEntriesService.getFoodEntriesForDate(user.id, DateTime.now());
      existingMeals = meals.where((meal) => meal.items.isNotEmpty).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de la récupération des repas existants: $e');
    }

    // Sauvegarder le contexte avant de fermer l'écran
    final currentContext = context;

    // Fermer l'écran du scanner
    Navigator.pop(context);

    // Attendre un délai pour permettre au popup de se fermer s'il était ouvert
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (currentContext.mounted) {
        MealSelectionBottomSheet.show(
          currentContext,
          titleKey: 'add_barcode_meal_title',
          subtitleKey: 'add_barcode_meal_subtitle',
          existingMeals: existingMeals,
          onExistingMealSelected: (meal) async {
            // Ajouter l'aliment au repas sélectionné
            try {
              final success = await FoodEntriesService.addFoodEntry(
                userId: user.id,
                mealName: meal.name,
                mealId: meal.id,
                foodItem: foodItem,
                consumedAt: DateTime.now(),
              );

              if (currentContext.mounted) {
                if (success) {
                  // Show celebration popup
                  CelebrationService().celebrateFoodEntry(
                    currentContext,
                    foodName: foodItem.name,
                    mealName: meal.name,
                  );

                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'food_added_to_meal_name'.tr(LocalizationService.instance.currentLanguageCode)
                          .replaceAll('{foodName}', foodItem.name)
                          .replaceAll('{mealName}', meal.name)
                      ),
                      backgroundColor: const Color(0xFF0B132B),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text('error_database_add_failed'.tr(LocalizationService.instance.currentLanguageCode)),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              }
            } catch (e) {
              if (kDebugMode) debugPrint('Erreur lors de l\'ajout: $e');
              if (currentContext.mounted) {
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  SnackBar(
                    content: Text('error_database_add_failed'.tr(LocalizationService.instance.currentLanguageCode)),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            }
          },
          onCreateNewMeal: () {
            // Afficher la sélection de type de nouveau repas
            NewMealTypeBottomSheet.show(
              currentContext,
              onMealTypeSelected: (mealType, time) async {
                // Créer un nouveau repas avec l'aliment
                try {
                  final mealId = await FoodEntriesService.generateMealId(
                    userId: user.id,
                    mealName: mealType,
                    forDate: DateTime.now(),
                  );

                  if (mealId != null) {
                    final success = await FoodEntriesService.addFoodEntry(
                      userId: user.id,
                      mealName: mealType,
                      mealId: mealId,
                      foodItem: foodItem,
                      consumedAt: DateTime.now(),
                    );

                    if (currentContext.mounted) {
                      if (success) {
                        // Show celebration popup
                        CelebrationService().celebrateFoodEntry(
                          currentContext,
                          foodName: foodItem.name,
                          mealName: mealType,
                        );

                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'food_added_to_new_meal'.tr(LocalizationService.instance.currentLanguageCode)
                                .replaceAll('{foodName}', foodItem.name)
                                .replaceAll('{mealType}', mealType)
                            ),
                            backgroundColor: const Color(0xFF0B132B),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text('error_creating_meal'.tr(LocalizationService.instance.currentLanguageCode)),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  if (kDebugMode) debugPrint('Erreur lors de la création du repas: $e');
                  if (currentContext.mounted) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(
                        content: Text('error_creating_meal'.tr(LocalizationService.instance.currentLanguageCode)),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      }
    });
  }
} 

/// La quantité d'un produit scanné : le grand chiffre, deux pas, et les
/// portions qu'on prend le plus souvent.
class _BarcodeQuantity extends StatelessWidget {
  const _BarcodeQuantity({
    required this.controller,
    required this.unit,
    required this.lang,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String unit;
  final String lang;
  final VoidCallback onChanged;

  static const List<double> _presets = [30, 50, 100, 150, 200, 250];

  void _step(int direction) {
    final current = double.tryParse(controller.text.isEmpty ? '0' : controller.text) ?? 0;
    _set((current + direction * 10).clamp(0, 5000).toDouble());
  }

  void _set(double value) {
    RyzeFeedback.tap();
    controller.text = value.truncateToDouble() == value ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final current = double.tryParse(controller.text) ?? -1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('quantity'.tr(lang), style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.3)),
        Row(
          children: [
            _QtyStep(icon: LucideIcons.minus, onTap: () => _step(-1)),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  IntrinsicWidth(
                    child: NumericTextField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      style: RyzeText.display(context, 9.2, weight: FontWeight.w600),
                      onChanged: (_) => onChanged(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: '0',
                      ),
                    ),
                  ),
                  SizedBox(width: context.vw(1.5)),
                  Text(unit, style: RyzeText.body(context, 3.9, color: RyzeColors.mute)),
                ],
              ),
            ),
            _QtyStep(icon: LucideIcons.plus, onTap: () => _step(1)),
          ],
        ),
        SizedBox(height: context.vw(3.1)),
        SizedBox(
          height: context.vw(9.2),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _presets.length,
            separatorBuilder: (_, __) => SizedBox(width: context.vw(2.1)),
            itemBuilder: (_, i) {
              final value = _presets[i];
              final on = current == value;
              return Pressable(
                onTap: () => _set(value),
                child: AnimatedContainer(
                  duration: RyzeDurations.tap,
                  curve: RyzeCurves.out,
                  padding: EdgeInsets.symmetric(horizontal: context.vw(3.6)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? RyzeColors.ink : RyzeColors.surf,
                    borderRadius: BorderRadius.circular(RyzeRadius.pill),
                    border: Border.all(color: on ? RyzeColors.ink : RyzeColors.line),
                  ),
                  child: Text(
                    '${value.toStringAsFixed(0)} $unit',
                    style: RyzeText.body(context, 3.3, weight: FontWeight.w600, color: on ? RyzeColors.surf : RyzeColors.ink),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QtyStep extends StatelessWidget {
  const _QtyStep({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: context.vw(12.3),
        height: context.vw(12.3),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          shape: BoxShape.circle,
          border: Border.all(color: RyzeColors.line),
        ),
        child: Icon(icon, size: context.vw(5.1), color: RyzeColors.ink),
      ),
    );
  }
}

/// Une valeur du produit : ce qu'elle vaut pour la quantité prise, et le champ
/// par 100 g quand on ouvre la correction.
class _BarcodeMacro extends StatelessWidget {
  const _BarcodeMacro({
    required this.label,
    required this.controller,
    required this.editing,
    required this.value,
    required this.suffix,
    required this.onChanged,
    this.hidden = false,
  });

  final String label;
  final TextEditingController controller;
  final bool editing;
  final double value;
  final String suffix;
  final VoidCallback onChanged;

  /// Les calories sont déjà écrites en grand au-dessus : cette ligne n'existe
  /// que pour les corriger.
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (hidden) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: editing && suffix == 'kcal' ? context.vw(2.6) : 0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: RyzeText.body(context, 3.6, color: RyzeColors.mute))),
          if (editing)
            SizedBox(
              width: context.vw(22),
              height: context.vw(9.7),
              child: NumericTextField(
                controller: controller,
                textAlign: TextAlign.right,
                onChanged: (_) => onChanged(),
                style: RyzeText.body(context, 3.6, weight: FontWeight.w600),
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: suffix,
                  suffixStyle: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                  contentPadding: EdgeInsets.symmetric(horizontal: context.vw(2.1), vertical: context.vw(1.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RyzeRadius.xs),
                    borderSide: const BorderSide(color: RyzeColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RyzeRadius.xs),
                    borderSide: const BorderSide(color: RyzeColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RyzeRadius.xs),
                    borderSide: const BorderSide(color: RyzeColors.ink),
                  ),
                ),
              ),
            )
          else
            Text(
              '${value.toStringAsFixed(value >= 100 ? 0 : 1)} $suffix',
              style: RyzeText.body(context, 3.6, weight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
