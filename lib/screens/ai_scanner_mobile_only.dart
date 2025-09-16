import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../models/nutrition_models.dart';
import '../components/ui/nutrition_widgets.dart';
import '../services/gemini_analysis_service.dart';
import '../services/gemini_analysis_service_v2.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../models/ai_analysis_models.dart';
import '../services/food_entries_service.dart';
import '../services/auth_service.dart';

class AIScannerScreenMobileOnly extends StatefulWidget {
  final bool isFromDashboard;
  final String? mealName;
  final String? mealId;

  const AIScannerScreenMobileOnly({
    super.key,
    this.isFromDashboard = false,
    this.mealName,
    this.mealId,
  });

  @override
  State<AIScannerScreenMobileOnly> createState() => _AIScannerScreenMobileOnlyState();
}

class _AIScannerScreenMobileOnlyState extends State<AIScannerScreenMobileOnly> with WidgetsBindingObserver {
  bool isAnalyzing = false;
  bool hasResult = false;
  bool isCameraInitialized = false;
  bool isFlashOn = false;
  bool showNoteInput = false;
  String? errorMessage;
  AIAnalysisResult? _analysisResult;
  String _aiNote = '';

  final TextEditingController _editableFoodNameController = TextEditingController();
  CameraController? _cameraController;
  bool isPermissionGranted = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  Future<void> _debugPermissions() async {
    print('=== DEBUG PERMISSIONS AI MOBILE SCANNER ===');
    final status = await Permission.camera.status;
    print('🔍 Camera status initial: $status');

    if (status.isDenied) {
      print('📱 Requesting camera permission...');
      final result = await Permission.camera.request();
      print('✅ Request result: $result');
    }

    final finalStatus = await Permission.camera.status;
    print('🎯 Final camera status: $finalStatus');
    print('=== END DEBUG AI MOBILE PERMISSIONS ===');
  }

  Future<void> _initializeScanner() async {
    print('🔍 AI SCANNER - Initializing camera (iOS 18 workaround)...');

    try {
      // iOS 18 FIX: Bypass permission_handler, use availableCameras() directly
      // iOS will automatically prompt for camera permission
      final cameras = await availableCameras();
      print('✅ AI SCANNER - Found ${cameras.length} cameras');
      
      if (cameras.isNotEmpty) {
        setState(() {
          isPermissionGranted = true;
        });

        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false, // Fix iOS 18: Désactiver microphone
        );

        await _cameraController!.initialize();
        print('✅ AI SCANNER - Camera initialized successfully');

        setState(() {
          isCameraInitialized = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ AI SCANNER - Camera error (likely permission denied): $e');
      setState(() {
        isPermissionGranted = false;
        isLoading = false;
        errorMessage = 'Camera permission denied or not available';
      });
    }
  }
  @override
  void dispose() {
    if (isPermissionGranted && isCameraInitialized && _cameraController != null) {
      _cameraController!.dispose();
    }
    _editableFoodNameController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _takePictureFromCamera() async {
    if (!isCameraInitialized || isAnalyzing || _cameraController == null) return;

    try {
      setState(() {
        isAnalyzing = true;
        errorMessage = null;
      });

      // Capture image using camera
      final XFile image = await _cameraController!.takePicture();
      await _analyzeImageFromPath(image.path);

    } catch (e) {
      setState(() {
        errorMessage = 'Error taking picture: $e';
        isAnalyzing = false;
      });
    }
  }

  Future<void> _analyzeImageFromPath(String imagePath) async {
    // Simulate analysis for now
    print('📸 Analyzing image: $imagePath');
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isAnalyzing = false;
      hasResult = true;
      _analysisResult = AIAnalysisResult(
        foodItems: [
          FoodAnalysisItem(
            name: 'Test Food Item',
            calories: 100,
            weight: 50.0,
            nutritionalInfo: NutritionalInfo(
              calories: 100,
              protein: 5.0,
              carbs: 15.0,
              fat: 2.0,
              fiber: 1.0,
              sugar: 3.0,
            ),
          ),
        ],
        confidence: 0.9,
        notes: 'Test analysis result',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            locService.currentLanguageCode == 'fr' ? 'Scanner IA' : 'AI Scanner',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          if (isCameraInitialized && !isAnalyzing)
            IconButton(
              icon: Icon(
                isFlashOn ? LucideIcons.flashlight : LucideIcons.flashlightOff,
                color: Colors.white,
              ),
              onPressed: () {
                // Toggle torch functionality disabled for now with camera package
                setState(() {
                  isFlashOn = !isFlashOn;
                });
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
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Initialisation de la caméra...' : 'Initializing camera...',
                style: const TextStyle(color: Colors.white),
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
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Permission caméra requise' : 'Camera permission required',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  locService.currentLanguageCode == 'fr' ? 'Ouvrir les paramètres' : 'Open settings',
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (hasResult && _analysisResult != null) {
      return _buildResultScreen();
    }

    return Stack(
      children: [
        // Camera Preview
        if (_cameraController != null && _cameraController!.value.isInitialized)
          CameraPreview(_cameraController!)
        else
          Container(
            color: Colors.black,
            child: Center(
              child: Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  locService.currentLanguageCode == 'fr' ? 'Caméra non initialisée' : 'Camera not initialized',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

        // Camera controls
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCameraButton(
                icon: LucideIcons.image,
                onTap: () => _pickImageFromGallery(),
              ),
              _buildCaptureButton(),
              _buildCameraButton(
                icon: LucideIcons.rotateCcw,
                onTap: () {
                  // Switch camera functionality disabled for now with camera package
                },
              ),
            ],
          ),
        ),

        // Loading overlay
        if (isAnalyzing)
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
                      locService.currentLanguageCode == 'fr' ? 'Analyse en cours...' : 'Analyzing...',
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

  Widget _buildCameraButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: isCameraInitialized && !isAnalyzing ? _takePictureFromCamera : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey, width: 4),
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        isAnalyzing = true;
      });

      // Analyze the selected image
      await _analyzeImageFromPath(image.path);
    }
  }

  Widget _buildResultScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.checkCircle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Analyse terminée!' : 'Analysis complete!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Food detected: ${_analysisResult!.foodItems.first.name}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  hasResult = false;
                  _analysisResult = null;
                });
              },
              child: Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  locService.currentLanguageCode == 'fr' ? 'Scanner à nouveau' : 'Scan again',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}