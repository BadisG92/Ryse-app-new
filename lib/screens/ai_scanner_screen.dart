import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/gemini_analysis_service_v2.dart';
import '../models/ai_analysis_models.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../models/nutrition_models.dart';
import '../services/food_entries_service.dart';
import '../services/auth_service.dart';
import '../services/translations.dart';
import '../components/nutrition_journal_hybrid.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

class AIScannerScreen extends StatefulWidget {
  final bool isFromDashboard;
  final String? mealName;
  final String? mealId;

  const AIScannerScreen({
    super.key,
    this.isFromDashboard = false,
    this.mealName,
    this.mealId,
  });

  @override
  State<AIScannerScreen> createState() => _AIScannerScreenState();
}

class _AIScannerScreenState extends State<AIScannerScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  String? _errorMessage;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  // Variables pour le zoom
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    debugPrint('🔥 [FLUX AI] 📸 ===== VERSION AVEC ZOOM ET NOTE =====');
    debugPrint('🔥 [FLUX AI] 📸 PAS d\'écran de choix - Caméra DIRECTE !');
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    debugPrint('🔥 [FLUX AI] 📹 Initialisation caméra native');
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Aucune caméra disponible';
          _isLoading = false;
        });
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Récupérer les niveaux de zoom min/max
      _minZoomLevel = await _cameraController!.getMinZoomLevel();
      _maxZoomLevel = await _cameraController!.getMaxZoomLevel();
      _currentZoomLevel = _minZoomLevel;
      _baseZoomLevel = _minZoomLevel;
      debugPrint('🔥 [FLUX AI] ✅ Caméra initialisée - Zoom: ${_minZoomLevel}x - ${_maxZoomLevel}x');

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🔥 [FLUX AI] ❌ Erreur caméra: $e');
      setState(() {
        _errorMessage = 'Erreur caméra: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  String _getLocalizedHint(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    return 'coach_detected_dish_name'.tr(localizationService.currentLanguageCode);
  }

  Future<void> _takePicture() async {
    debugPrint('🔥 [FLUX AI] 📸 Prise de photo');
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      debugPrint('🔥 [FLUX AI] ✅ Photo prise: ${image.path}');

      // Aller au preview screen avec note
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AIPreviewScreen(
            imagePath: image.path,
            isFromDashboard: widget.isFromDashboard,
            mealName: widget.mealName,
            mealId: widget.mealId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('🔥 [FLUX AI] ❌ Erreur photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    debugPrint('🔥 [FLUX AI] 🖼️ Ouverture galerie');
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('🔥 [FLUX AI] ✅ Image depuis galerie: ${image.path}');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AIPreviewScreen(
              imagePath: image.path,
              isFromDashboard: widget.isFromDashboard,
              mealName: widget.mealName,
              mealId: widget.mealId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔥 [FLUX AI] ❌ Erreur galerie: $e');
    }
  }

  void _toggleFlash() {
    if (_cameraController != null) {
      _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch
      );
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return _buildCameraScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr'
                    ? 'Initialisation de la caméra...'
                    : 'Initializing camera...',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.cameraOff, color: Colors.white, size: 64),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            'ai_scanner_title'.tr(locService.currentLanguageCode),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? LucideIcons.flashlight : LucideIcons.flashlightOff,
              color: Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Caméra preview plein écran avec zoom
          if (_isCameraInitialized)
            Positioned.fill(
              child: GestureDetector(
                onScaleStart: (ScaleStartDetails details) {
                  _baseZoomLevel = _currentZoomLevel;
                },
                onScaleUpdate: (ScaleUpdateDetails details) {
                  final double newZoom = (_baseZoomLevel * details.scale).clamp(_minZoomLevel, _maxZoomLevel);
                  _cameraController!.setZoomLevel(newZoom);
                  setState(() {
                    _currentZoomLevel = newZoom;
                  });
                },
                onScaleEnd: (ScaleEndDetails details) {
                  debugPrint('🔥 [FLUX AI] 🔍 Zoom final: ${_currentZoomLevel.toStringAsFixed(1)}x');
                },
                child: CameraPreview(_cameraController!),
              ),
            ),

          // Interface style iPhone
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, top: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton galerie
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.image,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Bouton capture principal (style iPhone)
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Espace vide pour garder la symétrie (plus de 3ème bouton)
                  const SizedBox(width: 50, height: 50),
                ],
              ),
            ),
          ),

          // Indicateur de zoom
          if (_currentZoomLevel > _minZoomLevel)
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentZoomLevel.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

// Écran de preview avec note
class AIPreviewScreen extends StatefulWidget {
  final String imagePath;
  final bool isFromDashboard;
  final String? mealName;
  final String? mealId;

  const AIPreviewScreen({
    super.key,
    required this.imagePath,
    this.isFromDashboard = false,
    this.mealName,
    this.mealId,
  });

  @override
  State<AIPreviewScreen> createState() => _AIPreviewScreenState();
}

class _AIPreviewScreenState extends State<AIPreviewScreen> {
  final TextEditingController _noteController = TextEditingController();
  static const int _maxNoteLength = 500;

  void _retakePicture() {
    Navigator.of(context).pop();
  }

  void _analyzePhoto() {
    debugPrint('🔥 [FLUX AI] 📝 Note: ${_noteController.text}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AIAnalysisScreen(
          imagePath: widget.imagePath,
          note: _noteController.text.trim(),
          isFromDashboard: widget.isFromDashboard,
          mealName: widget.mealName,
          mealId: widget.mealId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            locService.currentLanguageCode == 'fr' ? 'Prévisualisation' : 'Preview',
            style: const TextStyle(color: Color(0xFF0B132B)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image preview
            Container(
              height: 400,
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Note input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr'
                          ? 'Ajoute des précisions (optionnel)'
                          : 'Add extra details (optional)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr'
                          ? 'Ajoute les ingrédients, la cuisson ou la portion pour guider l’analyse'
                          : 'Mention ingredients, cooking style or portion to guide the analysis',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF0B132B).withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLength: _maxNoteLength,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ex: Salade césar avec poulet grillé, portion moyenne',
                      hintStyle: TextStyle(
                        color: const Color(0xFF0B132B).withOpacity(0.4),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF0B132B).withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF0B132B).withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0B132B),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Boutons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Bouton reprendre
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _retakePicture,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0B132B)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Consumer<LocalizationService>(
                        builder: (context, locService, child) => Text(
                          locService.currentLanguageCode == 'fr' ? 'Reprendre' : 'Retake',
                          style: const TextStyle(
                            color: Color(0xFF0B132B),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  // Bouton analyser
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _analyzePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B132B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Consumer<LocalizationService>(
                        builder: (context, locService, child) => Text(
                          locService.currentLanguageCode == 'fr' ? 'Analyser' : 'Analyze',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Écran d'analyse avec l'UI ORIGINALE pour les résultats
class AIAnalysisScreen extends StatefulWidget {
  final String imagePath;
  final String? note;
  final bool isFromDashboard;
  final String? mealName;
  final String? mealId;

  const AIAnalysisScreen({
    super.key,
    required this.imagePath,
    this.note,
    this.isFromDashboard = false,
    this.mealName,
    this.mealId,
  });

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  bool _isAnalyzing = true;
  bool _hasResult = false;
  AIAnalysisResult? _analysisResult;
  String? _errorMessage;
  File? _capturedImage;
  Uint8List? _capturedImageBytes;

  // Contrôleurs pour l'UI originale
  final TextEditingController _mealNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('🔥 [FLUX AI] 🤖 Démarrage analyse IA pour: ${widget.imagePath}');
    if (widget.note != null && widget.note!.isNotEmpty) {
      debugPrint('🔥 [FLUX AI] 📝 Note utilisateur: ${widget.note}');
    }
    _capturedImage = File(widget.imagePath);
    _startAnalysis();
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    super.dispose();
  }

  String _getLocalizedHint(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    return 'coach_detected_dish_name'.tr(localizationService.currentLanguageCode);
  }

  Future<void> _startAnalysis() async {
    try {
      final file = File(widget.imagePath);

      // Appeler le service Gemini avec la note utilisateur
      final result = await GeminiAnalysisServiceV2.analyzeImageWithFallback(
        file,
        userNote: widget.note,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;

          if (result.success && result.detectedFoods.isNotEmpty) {
            _hasResult = true;
            _errorMessage = null;
            // Mettre à jour le nom du repas avec le nom généré par l'IA
            _mealNameController.text = result.mealName ?? 'coach_detected_dish'.tr(LocalizationService.instance.currentLanguageCode);
            debugPrint('🔥 [FLUX AI] ✅ Analyse terminée avec succès');
          } else {
            _hasResult = false;
            _errorMessage = result.error ?? 'Aucun aliment détecté';
            debugPrint('🔥 [FLUX AI] ❌ Erreur d\'analyse: ${result.error}');
          }
        });
      }
    } catch (e) {
      debugPrint('🔥 [FLUX AI] ❌ Exception lors de l\'analyse: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _hasResult = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return _buildLoadingScreen();
    }

    if (_hasResult && _analysisResult != null) {
      return _buildResultScreen();
    }

    return _buildErrorScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            'coach_analysis'.tr(locService.currentLanguageCode),
            style: const TextStyle(color: Color(0xFF0B132B)),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF0B132B),
            ),
            const SizedBox(height: 24),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr'
                    ? 'Analyse en cours...'
                    : 'Analyzing...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr'
                    ? 'Identification des aliments'
                    : 'Identifying foods',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF0B132B).withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            locService.currentLanguageCode == 'fr' ? 'Erreur' : 'Error',
            style: const TextStyle(color: Color(0xFF0B132B)),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: const Icon(
                  LucideIcons.x,
                  size: 32,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  locService.currentLanguageCode == 'fr'
                      ? 'Erreur d\'analyse'
                      : 'Analysis Error',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF0B132B).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isAnalyzing = true;
                    _errorMessage = null;
                  });
                  _startAnalysis();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    locService.currentLanguageCode == 'fr' ? 'Réessayer' : 'Try Again',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI ORIGINALE pour les résultats
  Widget _buildResultScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' ? 'Aliments détectés' : 'Detected foods',
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

          // Nom du plat modifiable (visible seulement quand on a un résultat)
          if (_hasResult && _analysisResult != null && _analysisResult!.success)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' ? 'Nom du plat' : 'Dish name',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mealNameController,
                    decoration: InputDecoration(
                      hintText: _getLocalizedHint(context),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.pencil, size: 16),
                        onPressed: () {
                          // Focus sur le champ pour édition
                          FocusScope.of(context).requestFocus();
                        },
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),

          // Photo analysée
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: _capturedImage != null || _capturedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb && _capturedImageBytes != null
                        ? Image.memory(
                            _capturedImageBytes!,
                            fit: BoxFit.cover,
                          )
                        : _capturedImage != null
                            ? Image.file(
                                _capturedImage!,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.image,
                          size: 48,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Photo analysée',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Résultats de l'analyse
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Bilan nutritionnel
                if (_analysisResult != null && _analysisResult!.success)
                  _buildNutritionalSummary(),

                const SizedBox(height: 24),

                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    locService.currentLanguageCode == 'fr' ? 'Aliments détectés :' : 'Detected foods:',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Aliments détectés via IA
                if (_analysisResult != null && _analysisResult!.success)
                  ...(_analysisResult!.detectedFoods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final food = entry.value;
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        _buildDetectedFood(
                          name: food.name,
                          confidence: (food.confidence * 100).round(),
                          calories: food.calories,
                          quantity: '${food.estimatedQuantity.round()}g',
                          food: food,
                        ),
                      ],
                    );
                  }).toList())
                else
                  Center(
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        locService.currentLanguageCode == 'fr' ? 'Aucun aliment détecté' : 'No food detected',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_analysisResult == null || !_analysisResult!.success || _analysisResult!.detectedFoods.isEmpty) {
                        return;
                      }

                      // Si on vient du dashboard, déclencher la sélection de repas
                      if (widget.mealName != null && widget.mealId != null) {
                        // Flux depuis le journal - ajouter directement au repas sélectionné
                        await _addFoodsToSpecificMeal(widget.mealName!, widget.mealId!);
                      } else if (widget.isFromDashboard) {
                        // Flux depuis le dashboard - demander la sélection du repas
                        await _addFoodsToJournalWithSelection();
                      } else {
                        // Flux normal du scanner - demander la sélection du repas
                        await _addFoodsToJournalWithSelection();
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
                      builder: (context, locService, child) => Text(
                        locService.currentLanguageCode == 'fr' ? 'Ajouter tous les aliments' : 'Add all foods',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Retourner à la caméra
                      Navigator.of(context).popUntil((route) => route.isFirst);
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
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        locService.currentLanguageCode == 'fr' ? 'Reprendre une photo' : 'Take another photo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildNutritionalSummary() {
    if (_analysisResult == null || !_analysisResult!.success) {
      return const SizedBox.shrink();
    }

    final locService = LocalizationService.instance;

    // Calculer les totaux
    int totalCalories = 0;
    int totalProteins = 0;
    int totalCarbs = 0;
    int totalFats = 0;

    for (final food in _analysisResult!.detectedFoods) {
      totalCalories += food.calories;
      totalProteins += food.nutrition.proteins.round();
      totalCarbs += food.nutrition.carbs.round();
      totalFats += food.nutrition.fats.round();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.trendingUp,
                size: 16,
                color: Color(0xFF0B132B),
              ),
              const SizedBox(width: 8),
              Text(
                'nutritional_summary'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cercle avec gradient pour les calories
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$totalCalories',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3 valeurs de macros sans cercle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroValue(
                name: 'proteins'.tr(locService.currentLanguageCode),
                value: totalProteins,
                unit: 'g',
              ),
              _buildMacroValue(
                name: 'carbohydrates'.tr(locService.currentLanguageCode),
                value: totalCarbs,
                unit: 'g',
              ),
              _buildMacroValue(
                name: 'fats'.tr(locService.currentLanguageCode),
                value: totalFats,
                unit: 'g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroValue({
    required String name,
    required int value,
    required String unit,
  }) {
    return Column(
      children: [
        Text(
          '$value$unit',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B132B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectedFood({
    required String name,
    required int confidence,
    required int calories,
    required String quantity,
    required DetectedFood food,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: confidence >= 90
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$confidence%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: confidence >= 90
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFCA8A04),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$calories kcal • $quantity',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _editDetectedFood(name, calories, quantity, food),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
              ),
              child: const Icon(
                LucideIcons.pencil,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editDetectedFood(String name, int calories, String currentQuantity, DetectedFood food) {
    final quantity = double.tryParse(currentQuantity.replaceAll('g', '')) ?? 100;

    EditableFoodDetailsBottomSheet.show(
      context,
      name: name,
      calories: calories,
      proteins: food.nutrition.proteins,
      glucides: food.nutrition.carbs,
      lipides: food.nutrition.fats,
      quantity: quantity,
      isModified: false,
      onFoodSaved: (foodItem) {
        debugPrint('Aliment ${foodItem.name} enregistré avec modifications');
      },
    );
  }

  Future<void> _addFoodsToSpecificMeal(String mealName, String mealId) async {
    if (_analysisResult == null || !_analysisResult!.success || _analysisResult!.detectedFoods.isEmpty) {
      return;
    }

    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: utilisateur non connecté'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
        return;
      }

      final success = await FoodEntriesService.addAIFoodEntry(
        userId: user.id,
        mealName: mealName,
        detectedFoods: _analysisResult!.detectedFoods,
        aiMealName: _mealNameController.text.isNotEmpty ? _mealNameController.text : 'coach_detected_dish'.tr(LocalizationService.instance.currentLanguageCode),
        mealId: mealId, // Utiliser le meal_id du repas existant
        consumedAt: DateTime.now(),
      );

      if (mounted) {
        // Retourner à la page principale (accueil)
        Navigator.of(context).popUntil((route) => route.isFirst);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_analysisResult!.mealName ?? "Plat IA"} ajouté au $mealName'),
              backgroundColor: const Color(0xFF0B132B),
              action: SnackBarAction(
                label: 'Voir',
                textColor: Colors.white,
                onPressed: () {
                  // L'utilisateur peut naviguer manuellement vers le Journal
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('Erreur lors de l\'ajout au repas spécifique: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout au repas'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _addFoodsToJournalWithSelection() async {
    if (_analysisResult == null || !_analysisResult!.success || _analysisResult!.detectedFoods.isEmpty) {
      return;
    }

    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: utilisateur non connecté'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
        return;
      }

      final allMeals = await FoodEntriesService.getFoodEntriesForDate(user.id, DateTime.now());
      final existingMeals = allMeals.where((meal) => meal.items.isNotEmpty).toList();

      MealSelectionBottomSheet.show(
        context,
        titleKey: 'add_photo_meal_title',
        subtitleKey: 'add_photo_meal_subtitle',
        existingMeals: existingMeals,
        onExistingMealSelected: (Meal selectedMeal) async {
          await _addAIFoodToExistingMeal(selectedMeal, user.id);
        },
        onCreateNewMeal: () {
          NewMealTypeBottomSheet.show(
            context,
            onMealTypeSelected: (String mealType, String time) async {
              await _addAIFoodToNewMeal(mealType, user.id);
            },
          );
        },
      );

    } catch (e) {
      debugPrint('Erreur lors de l\'affichage de la sélection de repas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'affichage de la sélection de repas'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _addAIFoodToExistingMeal(Meal selectedMeal, String userId) async {
    try {
      final success = await FoodEntriesService.addAIFoodEntry(
        userId: userId,
        mealName: selectedMeal.name,
        detectedFoods: _analysisResult!.detectedFoods,
        aiMealName: _mealNameController.text.isNotEmpty ? _mealNameController.text : 'coach_detected_dish'.tr(LocalizationService.instance.currentLanguageCode),
        mealId: selectedMeal.id, // Utiliser le meal_id du repas existant
        consumedAt: DateTime.now(),
      );

      if (mounted) {
        // Retourner à la page principale (accueil)
        Navigator.of(context).popUntil((route) => route.isFirst);

        if (success) {
          // Afficher un message de succès avec action vers le Journal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_analysisResult!.mealName ?? "Plat IA"} ajouté au ${selectedMeal.name}'),
              backgroundColor: const Color(0xFF0B132B),
              action: SnackBarAction(
                label: 'Voir',
                textColor: Colors.white,
                onPressed: () {
                  // L'utilisateur peut naviguer manuellement vers le Journal
                  // ou on pourrait implémenter une navigation automatique ici
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('Erreur lors de l\'ajout au repas existant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout au repas'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _addAIFoodToNewMeal(String mealType, String userId) async {
    try {
      final success = await FoodEntriesService.addAIFoodEntry(
        userId: userId,
        mealName: mealType,
        detectedFoods: _analysisResult!.detectedFoods,
        aiMealName: _mealNameController.text.isNotEmpty ? _mealNameController.text : 'coach_detected_dish'.tr(LocalizationService.instance.currentLanguageCode),
        consumedAt: DateTime.now(),
      );

      if (mounted) {
        // Retourner à la page principale (accueil)
        Navigator.of(context).popUntil((route) => route.isFirst);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_analysisResult!.mealName ?? "Plat IA"} ajouté au $mealType'),
              backgroundColor: const Color(0xFF0B132B),
              action: SnackBarAction(
                label: 'Voir',
                textColor: Colors.white,
                onPressed: () {
                  // L'utilisateur peut naviguer manuellement vers le Journal
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('Erreur lors de l\'ajout au nouveau repas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout au nouveau repas'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }
}
